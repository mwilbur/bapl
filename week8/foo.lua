{
1 =   {
  params =     {
    };
  body =     {
    body =       {
      s1 =         {
        tag = 'assignment';
        value =           {
          eltype =             {
            size =               {
              value = 2;
              tag = 'number';
              };
            tag = 'new';
            };
          size =             {
            value = 2;
            tag = 'number';
            };
          tag = 'new';
          };
        lhs =           {
          value = 'a';
          tag = 'variable';
          };
        };
      s2 =         {
        s1 =           {
          tag = 'assignment';
          value =             {
            value = 1;
            tag = 'number';
            };
          lhs =             {
            index =               {
              value = 1;
              tag = 'number';
              };
            name =               {
              index =                 {
                value = 1;
                tag = 'number';
                };
              name =                 {
                value = 'a';
                tag = 'variable';
                };
              tag = 'indexed';
              };
            tag = 'indexed';
            };
          };
        s2 =           {
          s1 =             {
            tag = 'assignment';
            value =               {
              value = 2;
              tag = 'number';
              };
            lhs =               {
              index =                 {
                value = 2;
                tag = 'number';
                };
              name =                 {
                index =                   {
                  value = 1;
                  tag = 'number';
                  };
                name =                   {
                  value = 'a';
                  tag = 'variable';
                  };
                tag = 'indexed';
                };
              tag = 'indexed';
              };
            };
          s2 =             {
            s1 =               {
              tag = 'assignment';
              value =                 {
                value = 3;
                tag = 'number';
                };
              lhs =                 {
                index =                   {
                  value = 1;
                  tag = 'number';
                  };
                name =                   {
                  index =                     {
                    value = 2;
                    tag = 'number';
                    };
                  name =                     {
                    value = 'a';
                    tag = 'variable';
                    };
                  tag = 'indexed';
                  };
                tag = 'indexed';
                };
              };
            s2 =               {
              tag = 'assignment';
              value =                 {
                value = 4;
                tag = 'number';
                };
              lhs =                 {
                index =                   {
                  value = 2;
                  tag = 'number';
                  };
                name =                   {
                  index =                     {
                    value = 2;
                    tag = 'number';
                    };
                  name =                     {
                    value = 'a';
                    tag = 'variable';
                    };
                  tag = 'indexed';
                  };
                tag = 'indexed';
                };
              };
            tag = 'statements';
            };
          tag = 'statements';
          };
        tag = 'statements';
        };
      tag = 'statements';
      };
    tag = 'block';
    };
  name = 'main';
  tag = 'func';
  };
}